package resource_packer

import "core:bytes"
import "core:os"
import "core:fmt"
import "core:mem"
import "core:math/big"
import "core:thread"
import "core:strings"
import "core:math"
import "core:math/rand"
import "core:math/linalg"
import "core:reflect"
import "core:os/os2"
import "core:debug/trace"
import "base:runtime"


change_name :: proc(name: string, allocator : runtime.Allocator) -> (res:string, err:runtime.Allocator_Error) {
    res2 := strings.clone(name, allocator) or_return

    bytes := transmute([]u8)(res2)
    for &s in bytes {
        if s == '.' || s == ' ' || s == '-' || s == '/' || s == '\\' || s == ':' || s == '*' || s == '?' || s == '"' || s == '<' || s == '>' || s == '|' {
            s = '_'
        }
    }

    res = res2
    return
}

read_dir_recursive :: proc(path: string, allocator: runtime.Allocator) -> (files: []os2.File_Info, err: os2.Error) {
    xfit_data, xfit_data_err := os2.open("xfit_data.odin", {.Read, .Write, .Create, .Trunc}, os2.Permissions_Read_Write_All)
    if xfit_data_err != nil {
        err = xfit_data_err
        return
    }
    defer os2.close(xfit_data)

    xfit_datas, xfit_datas_err := os2.open("xfit_data.xdata", {.Read, .Write, .Create, .Trunc}, os2.Permissions_Read_Write_All)
    if xfit_datas_err != nil {
        err = xfit_datas_err
        return
    }
    defer os2.close(xfit_datas)

    value:strings.Builder
    strings.builder_init(&value, context.temp_allocator)
    defer strings.builder_destroy(&value)
    strings.write_string(&value, "\n@(rodata) data : DATA = ")

    header:strings.Builder
    strings.builder_init(&header, context.temp_allocator)
    defer strings.builder_destroy(&header)
    strings.write_string(&header, "package xfit_data\n\n")

    files_ := mem.make_non_zeroed_dynamic_array([dynamic]os2.File_Info, allocator)
    defer if err != nil {
        delete(files_)
    }

    __read_dir_recursive :: proc(path: string, files: ^[dynamic]os2.File_Info, header:^strings.Builder, insert:int, offset:^int, value:^strings.Builder, xfit_datas:^os2.File, allocator: runtime.Allocator) -> os2.Error {
        f, err_ := os2.open(path)
        if err_ != nil {
            return err_
        }
        if insert == 0 {
            strings.write_string(header, "DATA :: struct {\n")
        } else {
            for i in 0 ..< insert {
                 strings.write_string(header, "  ")
            }
            new_name := change_name(files[len(files) - 1].name, context.temp_allocator) or_return
            defer delete(new_name, context.temp_allocator)

            strings.write_string(header, new_name)
            strings.write_string(header, " : struct {\n")
        }
        strings.write_string(value, "{")

        it := os2.read_directory_iterator_create(f)
	    defer os2.read_directory_iterator_destroy(&it)
        
        for fi, index in os2.read_directory_iterator(&it) {
            _ = os2.read_directory_iterator_error(&it) or_break

            append(files, os2.file_info_clone(fi, allocator) or_return)

            if fi.type == .Directory {
                __read_dir_recursive(fi.fullpath, files, header, insert + 1, offset, value, xfit_datas, allocator) or_return
            } else {
                for i in 0 ..< insert {
                    strings.write_string(header,"  ")
                }
                strings.write_string(header, "  ")
                new_name := change_name(fi.name, context.temp_allocator) or_return
                defer delete(new_name, context.temp_allocator)
                new_str := fmt.aprintf("%s : [2]int,\n", new_name, allocator = context.temp_allocator)
                strings.write_string(value, "{")
                strings.write_int(value, offset^)
                strings.write_string(value, ",")
                strings.write_i64(value, fi.size)
                strings.write_string(value, "},")

                offset^ += int(fi.size)

                strings.write_string(header, new_str)

                dataFile := os2.read_entire_file_from_path(fi.fullpath, context.temp_allocator) or_return
                defer delete(dataFile, context.temp_allocator)

                os2.write(xfit_datas, dataFile) or_return
            }
        }

        _ = os2.read_directory_iterator_error(&it) or_return

        for i in 0 ..< insert {
            strings.write_string(header, "  ")
        }
        if insert == 0 {
            strings.write_string(header, "}")
            strings.write_string(value, "}")
        } else {
            strings.write_string(header, "},\n")
            strings.write_string(value, "},")
        }  

        return nil
    }

    offset := 0
    err = __read_dir_recursive(path, &files_, &header, 0, &offset, &value, xfit_datas, allocator)
    if err != nil {
        return
    }

    strings.write_string(&value, "\n")

    _ = os2.write_string(xfit_data, strings.to_string(header)) or_return
    _ = os2.write_string(xfit_data, strings.to_string(value)) or_return

    shrink(&files_)
    files = files_[:]

    return
}

main :: proc() {
    fi, fi_err := read_dir_recursive("data", context.temp_allocator)
      if fi_err != nil {
        fmt.println("Error reading directory 'data' : ", fi_err)
        return
    }
    defer for fi in fi {
        os2.file_info_delete(fi, context.temp_allocator)
    }

    fmt.println("Files in 'data' directory:")
    for file in fi {
        if file.type != .Directory {
             fmt.println(" -", file.fullpath, "(", file.size, "bytes)") 
        }
    }
}



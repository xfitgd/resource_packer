# Resource Packer

A tool for packing resource files into a single data file.

---

### Usage

#### 1. Compile

Download pre-compiled binaries or compile the project to create an executable.

```bash
# Add .exe extension on Windows
odin build resource_packer -o:speed -out:bin/resource_packer
```

#### 2. Run

Execute the program in a directory containing a `data` folder. The program recursively reads all files in the `data` folder and generates the following 3 files:

- `xfit_data.odin`: Odin source file containing metadata for resource files
- `xfit_data.xdata`: Single file containing all resource file data
- `xfit_data.h`: A header file for use in C

#### 3. Use in Your Project

After copying the generated files to your project, use them as follows:

1. Load the `xfit_data.xdata` file in your project.
2. Import/Include the `xfit_data.odin` or `xfit_data.h` file:

3. Use the data structure:

```odin
// Load xfit_data.xdata file into memory
data_file := os.read_entire_file("xfit_data.xdata") or_return
defer delete(data_file)

// Extract specific file data
file_info := xfit_data.data.BG_opus  // [2]int type
offset := file_info[0]  // Offset within xfit_data.xdata file
size := file_info[1]    // File size

// Extract actual file data
file_data := data_file[offset:offset+size]
```

### Data Structure

Each file in the `DATA` struct is defined as `[2]int` type:

- **First value (`[0]`)**: Starting offset of the file data within the `xfit_data.xdata` file (in bytes)
- **Second value (`[1]`)**: Size of the file (in bytes)

Folder structure is represented as nested structs. For example:

```odin
DATA :: struct {
  test_txt : [2]int,
  character : struct {
    walk0_png : [2]int,
    walk1_png : [2]int,
    // ...
  },
}
```


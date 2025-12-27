# Resource Packer

리소스 파일들을 단일 데이터 파일로 패킹하는 도구입니다.

## 사용 방법

### 1. 컴파일

미리 컴파일된 파일을 다운 받거나 프로젝트를 컴파일하여 실행 파일을 생성합니다.

```bash
# windows면 앞에 .exe 붙임
odin build resource_packer -o:speed -out:bin/resource_packer
```

### 2. 실행

`data` 폴더가 있는 디렉토리에서 프로그램을 실행합니다. 프로그램은 `data` 폴더 내의 모든 파일을 재귀적으로 읽어서 다음 두 파일을 생성합니다:

- `xfit_data.odin`: 리소스 파일의 메타데이터를 포함하는 Odin 소스 파일
- `xfit_data.xdata`: 모든 리소스 파일의 데이터가 포함된 단일 파일

### 3. 프로젝트에서 사용하기

생성된 파일들을 프로젝트에 복사한 후 다음과 같이 사용합니다:

1. `xfit_data.xdata` 파일을 프로젝트에서 읽습니다.
2. `xfit_data.odin` 파일을 import합니다:

```odin
import "path/to/xfit_data"
```

3. 데이터 구조체를 사용합니다:

```odin
// xfit_data.xdata 파일을 메모리에 로드
data_file := os.read_entire_file("xfit_data.xdata") or_return
defer delete(data_file)

// 특정 파일의 데이터 추출
file_info := xfit_data.data.BG_opus  // [2]int 타입
offset := file_info[0]  // xfit_data.xdata 파일 내의 오프셋
size := file_info[1]    // 파일 크기

// 실제 파일 데이터 추출
file_data := data_file[offset:offset+size]
```

## 데이터 구조

`DATA` 구조체 내의 각 파일은 `[2]int` 타입으로 정의되어 있습니다:

- **첫 번째 값 (`[0]`)**: `xfit_data.xdata` 파일 내에서 해당 파일 데이터의 시작 오프셋 (바이트 단위)
- **두 번째 값 (`[1]`)**: 해당 파일의 크기 (바이트 단위)

폴더 구조는 중첩된 구조체로 표현됩니다. 예를 들어:

```odin
DATA :: struct {
  BG_opus : [2]int,
  캐릭터 : struct {
    walk0_png : [2]int,
    walk1_png : [2]int,
    // ...
  },
}
```

## 예제

```odin
package main

import "core:os"
import "xfit_data"

main :: proc() {
    // 데이터 파일 로드
    data_file := os.read_entire_file("xfit_data.xdata") or_return
    defer delete(data_file)

    // 특정 파일 정보 가져오기
    bg_info := xfit_data.data.BG_opus
    offset := bg_info[0]
    size := bg_info[1]

    // 파일 데이터 추출
    bg_data := data_file[offset:offset+size]
    
    // 추출한 데이터 사용
    // ...
}
```


! SPDX-License-Identifier: MIT
! Build-time input limits shared by the CLI and reusable parser API.
module fi_limits
    implicit none
    private
    public :: max_source_bytes, max_tokens
    public :: max_symbols, max_procedures, max_generics, max_access_names, max_only_names
    ! Keep source sizes representable by default INTEGER indices (with headroom).
    integer, parameter :: max_source_bytes=1048576
    ! Includes the final synthetic statement separator and end-of-file token.
    integer, parameter :: max_tokens=262144
    ! Whole-source metadata limits, independent of active call depth and array storage.
    ! Enlarged metadata storage is allocated on the heap, never embedded on stack.
    integer, parameter :: max_symbols=8192, max_procedures=1024, max_generics=256
    integer, parameter :: max_access_names=1024, max_only_names=1024
end module

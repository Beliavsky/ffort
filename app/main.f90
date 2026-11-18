! SPDX-License-Identifier: MIT
program main
    use fi_driver, only: run_cli
    implicit none
    integer :: status
    call run_cli(status)
    if(status/=0) stop status, quiet=.true.
end program

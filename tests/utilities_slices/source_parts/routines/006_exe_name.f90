function exe_name() result(xname)
! return the program name, including directory
character (len=1000) :: xname
character (len=1000) :: dir_name
call getcwd(dir_name)
! call getarg(0,xname)
call get_command_argument(0,xname)
xname = trim(dir_name) // "\" // trim(xname)
end function exe_name
!

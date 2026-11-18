function unix() result(is_unix)
! test if the operating system is Unix
logical :: is_unix
character (len=100) :: path
call get_environment_variable("PATH",path)
is_unix = path(1:1) == "/"
end function unix
!

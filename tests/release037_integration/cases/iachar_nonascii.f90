program main
implicit none
character(1)::c
c='€'
write(*,'(a)')'before'
print *,7,iachar(c)
end program

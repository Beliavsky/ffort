program main
implicit none
character(3)::a(3)
a='old'
call fill(a)
print '(a)',a
contains
subroutine fill(x)
character(3),intent(inout)::x(:)
write(x(2),'(i0)')7
end subroutine
end program

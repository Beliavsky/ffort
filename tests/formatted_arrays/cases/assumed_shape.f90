program main
implicit none
integer::a(5)=[1,2,3,4,5]
call show(a)
contains
subroutine show(a)
integer,intent(in)::a(:)
print '(2i3)',a
end subroutine
end program

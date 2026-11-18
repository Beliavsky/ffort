program main
implicit none
print '(a)',labels(3)
contains
function labels(n) result(a)
integer,intent(in)::n
character(2)::a(n)
integer::i
do i=1,n
write(a(i),'(i2.2)')i+6
end do
end function
end program

program main
implicit none
integer::i
print '(3a)', (render(i),i=1,3)
contains
function render(n) result(s)
integer,intent(in)::n
integer::i
character(12)::s
write(s,'(6(i0,a))') (i,":",i=1,n)
end function
end program

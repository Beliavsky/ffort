program elemental_actions
implicit none
integer::i
do i=1,2
call bump(i)
end do
contains
elemental subroutine bump(xx)
integer,intent(inout)::xx
xx=xx+1
end subroutine bump

end program

program elemental_actions
implicit none
integer::aa
aa=2
call wrap(aa)
contains
elemental subroutine bump(xx)
integer,intent(inout)::xx
xx=xx+1
end subroutine bump
simple elemental subroutine wrap(xx)
integer,intent(inout)::xx
call bump(xx)
end subroutine wrap

end program

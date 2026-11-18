program elemental_actions
implicit none
integer::aa(3),bb(3)
call copy_to(aa,bb)
contains
elemental subroutine copy_to(src,dst)
integer,intent(in)::src
integer,intent(out)::dst
dst=src
end subroutine copy_to

end program

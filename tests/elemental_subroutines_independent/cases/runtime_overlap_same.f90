program elemental_actions
implicit none
integer::aa(3)
aa=2
call copy_to(aa,aa)
contains
elemental subroutine copy_to(src,dst)
integer,intent(in)::src
integer,intent(out)::dst
dst=src
end subroutine copy_to

end program

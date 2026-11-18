program elemental_actions
implicit none
integer::aa(3),zz
call copy_to(zz,aa)
print *,aa
contains
elemental subroutine copy_to(src,dst)
integer,intent(in)::src
integer,intent(out)::dst
dst=9
end subroutine copy_to

end program

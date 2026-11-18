program elemental_actions
implicit none
integer::aa(0),zz
call copy_to(zz,aa)
print *,size(aa)
contains
elemental subroutine copy_to(src,dst)
integer,intent(in)::src
integer,intent(out)::dst
dst=src
end subroutine copy_to

end program

program elemental_actions
implicit none
integer::aa,bb
print *,991
aa=2
call copy_to(src=aa,bb)
contains
elemental subroutine copy_to(src,dst)
integer,intent(in)::src
integer,intent(out)::dst
dst=src
end subroutine copy_to

end program

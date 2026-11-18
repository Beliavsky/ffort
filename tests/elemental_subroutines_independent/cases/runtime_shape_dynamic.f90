program elemental_actions
implicit none
integer::aa(4),bb(4),n
aa=2
n=3
call copy_to(aa(1:n),bb(1:2))
contains
elemental subroutine copy_to(src,dst)
integer,intent(in)::src
integer,intent(out)::dst
dst=src
end subroutine copy_to

end program

program elemental_actions
implicit none
integer::aa(4)
aa(1)=1
aa(2)=2
aa(3)=3
aa(4)=4
call copy_to(aa+aa(1),aa)
print *,aa
contains
elemental subroutine copy_to(src,dst)
integer,intent(in)::src
integer,intent(out)::dst
dst=src
end subroutine copy_to

end program

program elemental_actions
implicit none
integer::aa(5),bb(3)
aa(1)=1
aa(2)=2
aa(3)=3
aa(4)=4
aa(5)=5
call copy_to(aa(5:1:-2),bb(3:1:-1))
print *,bb
contains
elemental subroutine copy_to(src,dst)
integer,intent(in)::src
integer,intent(out)::dst
dst=10*src
end subroutine copy_to

end program

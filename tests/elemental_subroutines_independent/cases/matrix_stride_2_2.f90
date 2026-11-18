program elemental_actions
implicit none
integer::aa(3,4),bb(2,2)
aa(1,1)=11
aa(2,1)=12
aa(3,1)=13
aa(1,2)=21
aa(2,2)=22
aa(3,2)=23
aa(1,3)=31
aa(2,3)=32
aa(3,3)=33
aa(1,4)=41
aa(2,4)=42
aa(3,4)=43
call copy_to(aa(1:3:2,1:3:2),bb)
print *,bb
contains
elemental subroutine copy_to(src,dst)
integer,intent(in)::src
integer,intent(out)::dst
dst=src
end subroutine copy_to

end program

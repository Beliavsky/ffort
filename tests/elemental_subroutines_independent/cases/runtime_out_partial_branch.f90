program elemental_actions
implicit none
integer::aa(2),bb(2)
aa(1)=1
aa(2)=2
bb=9
call act(aa,bb)
print *,bb(1)
print *,bb(2)
contains
elemental subroutine act(src,dst)
integer,intent(in)::src
integer,intent(out)::dst
if(src==1)dst=7
end subroutine act

end program

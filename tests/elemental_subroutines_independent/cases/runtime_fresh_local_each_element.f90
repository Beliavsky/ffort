program elemental_actions
implicit none
integer::aa(2)
aa(1)=1
aa(2)=2
call act(aa)
contains
impure elemental subroutine act(xx)
integer,intent(inout)::xx
integer::local
if(xx==1)local=7
xx=local
print *,xx
end subroutine act

end program

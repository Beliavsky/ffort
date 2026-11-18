program elemental_actions
implicit none
integer::aa(2,3)
aa(1,1)=11
aa(2,1)=12
aa(1,2)=21
aa(2,2)=22
aa(1,3)=31
aa(2,3)=32
call bump(aa)
print *,aa
contains
impure elemental subroutine bump(xx)
integer,intent(inout)::xx
print *,xx
xx=xx+100
end subroutine bump

end program

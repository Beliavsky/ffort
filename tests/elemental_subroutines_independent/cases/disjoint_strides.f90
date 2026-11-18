program elemental_actions
implicit none
integer::aa(6)
aa(1)=1
aa(2)=2
aa(3)=3
aa(4)=4
aa(5)=5
aa(6)=6
call exchange(aa(1:6:2),aa(2:6:2))
print *,aa
contains
elemental subroutine exchange(xx,yy)
integer,intent(inout)::xx,yy
integer::temp
temp=xx
xx=yy
yy=temp
end subroutine exchange

end program

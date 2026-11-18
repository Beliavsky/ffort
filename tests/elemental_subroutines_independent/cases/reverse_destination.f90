program elemental_actions
implicit none
integer::aa(5),bb(3)
aa(1)=1
aa(2)=2
aa(3)=3
aa(4)=4
aa(5)=5
bb=2
call work(aa(5:1:-2),bb,aa(2:4:2))
contains
elemental subroutine work(xx,yy,zz)
integer,intent(inout)::xx
integer,intent(in)::yy
integer,intent(out)::zz
zz=xx+yy
xx=xx*yy
end subroutine work

end program

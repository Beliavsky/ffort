program elemental_actions
implicit none
integer::aa(-2:0),bb(4:6),cc(9:11)
aa(-2)=2
aa(-1)=3
aa(0)=4
bb(4)=5
bb(5)=6
bb(6)=7
call work(aa,bb,cc)
print *,aa,cc
contains
elemental subroutine work(xx,yy,zz)
integer,intent(inout)::xx
integer,intent(in)::yy
integer,intent(out)::zz
zz=xx+yy
xx=xx*yy
end subroutine work

end program

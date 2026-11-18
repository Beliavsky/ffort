program elemental_actions
implicit none
integer::aa(2),bb(2)
aa=2
call work(zz=bb,yy=3,xx=aa)
print *,aa,bb
contains
elemental subroutine work(xx,yy,zz)
integer,intent(inout)::xx
integer,intent(in)::yy
integer,intent(out)::zz
zz=xx+yy
xx=xx*yy
end subroutine work

end program

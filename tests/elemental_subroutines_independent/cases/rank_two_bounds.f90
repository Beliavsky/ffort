program elemental_actions
implicit none
integer::aa(-1:0,4:6),bb(2,3)
aa=3
call work(aa,2,bb)
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

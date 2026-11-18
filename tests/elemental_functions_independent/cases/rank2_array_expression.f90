program elemental_test
implicit none
integer::aa(-1:0,4:5)
aa(-1,4)=7
aa(0,4)=8
aa(-1,5)=9
aa(0,5)=10
print *,combine(aa+1,compute(aa))
contains
elemental integer function combine(xx,yy) result(rr)
integer,intent(in)::yy,xx
rr=10*xx+yy
end function combine
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute

end program

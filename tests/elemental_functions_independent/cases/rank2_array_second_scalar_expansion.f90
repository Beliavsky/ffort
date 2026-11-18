program elemental_test
implicit none
integer::aa(-1:0,4:5)
aa(-1,4)=7
aa(0,4)=8
aa(-1,5)=9
aa(0,5)=10
print *,combine(2,aa)
contains
elemental integer function combine(xx,yy) result(rr)
integer,intent(in)::yy,xx
rr=10*xx+yy
end function combine

end program

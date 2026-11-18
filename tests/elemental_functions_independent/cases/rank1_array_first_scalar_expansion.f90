program elemental_test
implicit none
integer::aa(-1:1)
aa(-1)=1
aa(0)=2
aa(1)=3
print *,combine(aa,2)
contains
elemental integer function combine(xx,yy) result(rr)
integer,intent(in)::yy,xx
rr=10*xx+yy
end function combine

end program

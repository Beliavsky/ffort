program elemental_test
implicit none
integer::aa(3)
aa(1)=2
aa(2)=4
aa(3)=6
print *,combine(aa,aa)
contains
elemental integer function combine(xx,yy) result(rr)
integer,intent(in)::yy,xx
rr=10*xx+yy
end function combine

end program

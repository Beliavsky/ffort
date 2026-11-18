program elemental_test
implicit none
integer::aa(4),nn
aa=2
nn=3
print *,112
print *,combine(aa(1:nn),aa(1:2))
contains
elemental integer function combine(xx,yy) result(rr)
integer,intent(in)::yy,xx
rr=10*xx+yy
end function combine

end program

program elemental_test
implicit none
integer::aa(0,3),nn
nn=2
print *,112
print *,combine(aa(:,1:nn),aa)
contains
elemental integer function combine(xx,yy) result(rr)
integer,intent(in)::yy,xx
rr=10*xx+yy
end function combine

end program

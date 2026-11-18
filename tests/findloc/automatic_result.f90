program p
print *,f(reshape([1,2,2,1],[2,2]),2)
contains
function f(a,v) result(b)
integer,intent(in)::a(:,:),v
integer::b(size(a,2))
b=findloc(a,v,dim=1)
end function
end program

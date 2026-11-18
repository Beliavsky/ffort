program p
print *,f(2)
contains
integer function f(v) result(i)
integer,optional,intent(in)::v
if(present(v)) then
i=findloc([1,2,3],v,dim=1)
else
i=-1
end if
end function
end program

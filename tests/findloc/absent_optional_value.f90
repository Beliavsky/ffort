program p
print *,f()
contains
integer function f(v) result(i)
integer,optional,intent(in)::v
i=findloc([1,2,3],v,dim=1)
end function
end program

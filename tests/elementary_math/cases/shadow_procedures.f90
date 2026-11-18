program p
implicit none
print *,dim(2),sign(3),log_gamma(4)
contains
integer function dim(x)
integer,intent(in)::x
dim=x+10
end function
integer function sign(x)
integer,intent(in)::x
sign=x+20
end function
integer function log_gamma(x)
integer,intent(in)::x
log_gamma=x+30
end function
end program

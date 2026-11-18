module first
implicit none
integer,parameter::n=2,a(n)=[2,3],m=n+1
character(3),parameter::str_a='one',str_b='two',strs(2)=[str_a,str_b]
end module
module second
use first,only:n,a,m,strs
implicit none
private
public::values,words
integer,parameter::values(n)=[a(2),m]
character(3),parameter::words(2)=strs
end module
program main
use second,only:values,words
implicit none
print *,values,words
end program

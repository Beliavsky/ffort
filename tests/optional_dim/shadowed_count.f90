program p
implicit none
print *,count(),count(n=3),kind(count()),dble(count())
contains
integer function count(n)
integer,optional,intent(in)::n
count=7
if(present(n)) count=n
end function
end program

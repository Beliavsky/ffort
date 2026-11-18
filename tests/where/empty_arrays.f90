program p
implicit none
integer::a(0),b(0)
where(a>0) b=a/0
print *,size(b)
end program

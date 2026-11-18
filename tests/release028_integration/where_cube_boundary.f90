program demo
implicit none
integer::a(1,1,1)
a=0
where(a==0) a=1
print *,a
end program

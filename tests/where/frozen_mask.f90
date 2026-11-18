program p
implicit none
integer::a(4)=[1,2,3,4],b(4)=0
where(a>2)
a=0
b=a+8
elsewhere
b=-1
end where
print *,a,b
end program

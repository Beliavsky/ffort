program p
implicit none
integer::a(4)=[0,2,0,4],b(4)=0
where(a==0)
b=-1
elsewhere(8/a>2)
b=8/a
elsewhere
b=9
end where
print *,b
end program

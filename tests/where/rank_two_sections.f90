program p
integer::a(3,2),b(3,2)
a=reshape([1,2,3,4,5,6],[3,2])
b=0
where(a>2) b(3:1:-1,:)=a
print *,b
end program

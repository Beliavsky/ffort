program p
integer::a(3,2),b(3)
a=reshape([1,2,3,4,5,6],[3,2]);b=-1
where(a(:,2)>4) b=a(:,1)
print *,b
end program

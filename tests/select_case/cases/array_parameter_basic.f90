program p
implicit none
integer,parameter::a(-2:0)=[1,2,3]
integer,parameter::b=a(0)
print *,a,size(a),sum(a),a(-1),b
end program p

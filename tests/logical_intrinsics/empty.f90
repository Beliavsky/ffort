program p
implicit none
logical :: x(0),a(0,3),b(2,0)
print *,all(x),any(x),count(x),all(x,1),any(x,1),count(x,1,8)
print *,all(a),any(a),count(a),all(a,1),any(a,1),count(a,1)
print *,all(b,2),any(b,2),count(b,2)
print *,size(all(a,2)),size(any(b,1)),size(count(b,1))
print *,size(merge(1,0,a)),size(dble(count(a,2)))
end program

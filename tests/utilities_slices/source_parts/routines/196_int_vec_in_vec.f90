pure function int_vec_in_vec(ivec,jvec) result(tf)
integer, intent(in) :: ivec(:),jvec(:)
logical             :: tf(size(ivec))
integer             :: i
forall (i=1:size(ivec)) tf(i) = int_in_vec(ivec(i),jvec)
end function int_vec_in_vec
!

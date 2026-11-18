function positive_int_vec(ivec) result(jvec)
integer, intent(in) :: ivec(:)
integer             :: jvec(count(ivec>0))
jvec = pack(ivec,ivec>0)
end function positive_int_vec
!

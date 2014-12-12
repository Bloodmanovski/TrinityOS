﻿module Library.LinkedList;


class LinkedList(T) {
	private LinkedListNode!T _head;
	private long _count;
	private long _version;

	@property long Count() {
		return _count;
	}

	@property LinkedListNode!T First() {
		return _head;
	}

	@property LinkedListNode!T Last() {
		return _head is null ? null : _head._prev;
	}

	this() {

	}

	~this() {
		Clear();
	}

	LinkedListNode!T Add(T value) {
		return AddLast(value);
	}

	LinkedListNode!T AddAfter(LinkedListNode!T node, T value) {
		ValidateNode(node);
		LinkedListNode!T result = new LinkedListNode!T(node._list, value);
		InternalInsertNodeBefore(node._next, result);
		return result;
	}

	void AddAfter(LinkedListNode!T node, LinkedListNode!T newNode) {
		ValidateNode(node);
		ValidateNewNode(newNode);
		InternalInsertNodeBefore(node._next, newNode);
		newNode._list = this;
	}

	LinkedListNode!T AddBefore(LinkedListNode!T node, T value) {
		ValidateNode(node);
		LinkedListNode!T result = new LinkedListNode!T(node._list, value);
		InternalInsertNodeBefore(node, result);

		if (node is _head)
			_head = result;

		return result;
	}
	
	void AddBefore(LinkedListNode!T node, LinkedListNode!T newNode) {
		ValidateNode(node);
		ValidateNewNode(newNode);
		InternalInsertNodeBefore(node, newNode);
		newNode._list = this;

		if (node is _head)
			_head = newNode;
	}

	LinkedListNode!T AddFirst(T value) {
		LinkedListNode!T result = new LinkedListNode!T(this, value);

		if (_head is null)
			InternalInsertNodeToEmptyList(result);
		else {
			InternalInsertNodeBefore(_head, result);
			_head = result;
		}

		return result;
	}

	void AddFirst(LinkedListNode!T node) {
		ValidateNewNode(node);
		
		if (_head is null)
			InternalInsertNodeToEmptyList(node);
		else {
			InternalInsertNodeBefore(_head, node);
			_head = node;
		}

		node._list = this;
	}

	LinkedListNode!T AddLast(T value) {
		LinkedListNode!T result = new LinkedListNode!T(this, value);
		
		if (_head is null)
			InternalInsertNodeToEmptyList(result);
		else
			InternalInsertNodeBefore(_head, result);
		
		return result;
	}
	
	void AddLast(LinkedListNode!T node) {
		ValidateNewNode(node);
		
		if (_head is null)
			InternalInsertNodeToEmptyList(node);
		else
			InternalInsertNodeBefore(_head, node);
		
		node._list = this;
	}

	void Clear() {
		auto current = _head;

		while (current !is null) {
			auto tmp = current;
			current = current.Next;
			tmp.Invalidate();
			delete tmp;
		}

		_head = null;
		_count = 0;
		_version++;
	}

	bool Contains(T value) {
		return Find(value) !is null;
	}

	LinkedListNode!T Find(T value) {
		LinkedListNode!T node = _head;

		if (node) {
			do {
				if (value is node._item)
					return node;
				node = node._next;
			} while (node !is _head);
		}

		return null;
	}

	LinkedListNode!T FindLast(T value) {
		if (_head is null)
			return null;

		LinkedListNode!T last = _head._prev;
		LinkedListNode!T node = last;
		
		if (node) {
			do {
				if (value is node._item)
					return node;
				node = node._prev;
			} while (node !is last);
		}
		
		return null;
	}

	bool Remove(T value) {
		LinkedListNode!T node = Find(value);

		if (node) {
			InternalRemoveNode(node);
			return true;
		}

		return false;
	}

	void Remove(LinkedListNode!T node) {
		ValidateNode(node);
		InternalRemoveNode(node);
	}

	void RemoveFirst() in {
		if (_head is null)
			assert(0);
	} body {
		InternalRemoveNode(_head);
	}

	void RemoveLast() in {
		if (_head is null)
			assert(0);
	} body {
		InternalRemoveNode(_head._prev);
	}

	int opApply(int delegate(ref LinkedListNode!T) dg) {
		int result;

		for (auto x = _head; x !is null; x = x.Next) {
			result = dg(x);
			if (result)
				break;
		}

		return result;
	}

	int opApplyReverse(int delegate(ref LinkedListNode!T) dg) {
		int result;
		
		for (auto x = _head; x !is null; x = x.Prev) {
			result = dg(x);
			if (result)
				break;
		}
		
		return result;
	}

	private void InternalInsertNodeBefore(LinkedListNode!T node, LinkedListNode!T newNode) {
		newNode._next    = node;
		newNode._prev    = node._prev;
		node._prev._next = newNode;
		node._prev       = newNode;            
		_version++;
		_count++;
	}

	private void InternalInsertNodeToEmptyList(LinkedListNode!T newNode) in {
		assert(_head is null && !_count, "LinkedList must be empty when this method is called!");
	} body {
		newNode._next = newNode;
		newNode._prev = newNode;
		_head = newNode;
		_version++;
		_count++; 
	}

	private void InternalRemoveNode(LinkedListNode!T node) in {
		assert(node._list is this, "Deleting the node from another list!");   
		assert(_head !is null, "This method shouldn't be called on empty list!");
	} body {
		if (node._next == node) {
			_head = null;
		} else {
			node._next._prev = node._prev;
			node._prev._next = node._next;
			
			if (_head is node)
				_head = node._next;
		}

		node.Invalidate();
		delete node;
		_count--;
		_version++;
	}

	private void ValidateNewNode(LinkedListNode!T node) {
		if (node is null || node._list !is null)
			assert(false);
	}

	private void ValidateNode(LinkedListNode!T node) {
		if (node is null || node._list !is this)
			assert(false);
	}
}


final class LinkedListNode(T) {
	private LinkedList!T _list;
	private LinkedListNode!T _next;
	private LinkedListNode!T _prev;
	private T _item;

	this(T value) {
		_item = value;
	}

	private this(LinkedList!T list, T value) {
		_list = list;
		_item = value;
	}

	@property LinkedList!T List() {
		return _list;
	}

	@property LinkedListNode!T Next() {
		return _next is null || _next is _list._head ? null : _next;
	}

	@property LinkedListNode!T Prev() {
		return _prev is null || _prev is _list._head ? null : _prev;
	}

	@property ref T Value() { 
		return _item;
	}

	private void Invalidate() {
		_list = null;
		_next = null;
		_prev = null;
	}
}
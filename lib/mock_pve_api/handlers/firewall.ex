# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.Firewall do
  @moduledoc """
  Handler for PVE Firewall endpoints.

  Covers cluster-level, node-level, VM-level, and container-level firewall
  management: options, rules, security groups (cluster-only), aliases, and
  IP sets.

  Internally, most operations delegate to shared scope-based helpers
  (`do_get_options/2`, `do_list_rules/2`, etc.) so that cluster, node, VM,
  and container scopes share the same logic.
  """

  import Plug.Conn
  require Logger
  alias MockPveApi.State

  # ────────────────────────────────────────────────
  # Scope helpers — extract scope from conn
  # ────────────────────────────────────────────────

  defp vm_scope(conn), do: {:vm, conn.path_params["vmid"]}
  defp ct_scope(conn), do: {:container, conn.path_params["vmid"]}

  # ────────────────────────────────────────────────
  # Cluster Firewall — public API (thin wrappers)
  # ────────────────────────────────────────────────

  def get_cluster_firewall_options(conn), do: do_get_options(conn, :cluster)
  def update_cluster_firewall_options(conn), do: do_update_options(conn, :cluster)
  def list_cluster_firewall_rules(conn), do: do_list_rules(conn, :cluster)
  def create_cluster_firewall_rule(conn), do: do_create_rule(conn, :cluster)
  def get_cluster_firewall_rule(conn), do: do_get_rule(conn, :cluster)
  def update_cluster_firewall_rule(conn), do: do_update_rule(conn, :cluster)
  def delete_cluster_firewall_rule(conn), do: do_delete_rule(conn, :cluster)

  # Cluster aliases & ipsets (also scope-based)
  def list_aliases(conn), do: do_list_aliases(conn, :cluster)
  def create_alias(conn), do: do_create_alias(conn, :cluster)
  def get_alias(conn), do: do_get_alias(conn, :cluster)
  def update_alias(conn), do: do_update_alias(conn, :cluster)
  def delete_alias(conn), do: do_delete_alias(conn, :cluster)

  def list_ipsets(conn), do: do_list_ipsets(conn, :cluster)
  def create_ipset(conn), do: do_create_ipset(conn, :cluster)
  def get_ipset(conn), do: do_get_ipset(conn, :cluster)
  def delete_ipset(conn), do: do_delete_ipset(conn, :cluster)
  def get_ipset_entry(conn), do: do_get_ipset_entry(conn, :cluster)
  def update_ipset_entry(conn), do: do_update_ipset_entry(conn, :cluster)
  def delete_ipset_entry(conn), do: do_delete_ipset_entry(conn, :cluster)
  def add_ipset_entry(conn), do: do_add_ipset_entry(conn, :cluster)

  # ────────────────────────────────────────────────
  # Security Groups — cluster-only (no shared scope)
  # ────────────────────────────────────────────────

  def list_security_groups(conn) do
    fw = State.get_firewall(:cluster)

    groups =
      Enum.map(fw.groups, fn {name, group} ->
        %{group: name, comment: Map.get(group, :comment, ""), rules: length(group.rules)}
      end)

    json_resp(conn, 200, groups)
  end

  def create_security_group(conn) do
    params = conn.body_params
    name = Map.get(params, "group")

    if name do
      fw = State.get_firewall(:cluster)

      if Map.has_key?(fw.groups, name) do
        json_error(conn, 400, "security group '#{name}' already exists")
      else
        group = %{comment: Map.get(params, "comment", ""), rules: []}
        new_groups = Map.put(fw.groups, name, group)
        State.update_firewall(:cluster, %{groups: new_groups})
        json_resp(conn, 200, nil)
      end
    else
      json_error(conn, 400, "property 'group' is missing and it is not optional")
    end
  end

  def get_security_group(conn) do
    group_name = conn.path_params["group"]
    fw = State.get_firewall(:cluster)

    case Map.get(fw.groups, group_name) do
      nil -> json_error(conn, 404, "no such security group '#{group_name}'")
      group -> json_resp(conn, 200, rules_with_pos(group.rules))
    end
  end

  def delete_security_group(conn) do
    group_name = conn.path_params["group"]
    fw = State.get_firewall(:cluster)

    if Map.has_key?(fw.groups, group_name) do
      new_groups = Map.delete(fw.groups, group_name)
      State.update_firewall(:cluster, %{groups: new_groups})
      json_resp(conn, 200, nil)
    else
      json_error(conn, 404, "no such security group '#{group_name}'")
    end
  end

  def create_security_group_rule(conn) do
    group_name = conn.path_params["group"]
    params = conn.body_params
    fw = State.get_firewall(:cluster)

    case Map.get(fw.groups, group_name) do
      nil ->
        json_error(conn, 404, "no such security group '#{group_name}'")

      group ->
        rule = build_rule(params)
        new_rules = group.rules ++ [rule]
        new_group = %{group | rules: new_rules}
        new_groups = Map.put(fw.groups, group_name, new_group)
        State.update_firewall(:cluster, %{groups: new_groups})
        json_resp(conn, 200, nil)
    end
  end

  def get_security_group_rule(conn) do
    group_name = conn.path_params["group"]
    pos = parse_pos(conn.path_params["pos"])
    fw = State.get_firewall(:cluster)

    case Map.get(fw.groups, group_name) do
      nil ->
        json_error(conn, 404, "no such security group '#{group_name}'")

      group ->
        case Enum.at(group.rules, pos) do
          nil -> json_error(conn, 400, "no rule at position #{pos}")
          rule -> json_resp(conn, 200, Map.put(rule, :pos, pos))
        end
    end
  end

  def update_security_group_rule(conn) do
    group_name = conn.path_params["group"]
    pos = parse_pos(conn.path_params["pos"])
    params = conn.body_params
    fw = State.get_firewall(:cluster)

    case Map.get(fw.groups, group_name) do
      nil ->
        json_error(conn, 404, "no such security group '#{group_name}'")

      group ->
        case Enum.at(group.rules, pos) do
          nil ->
            json_error(conn, 400, "no rule at position #{pos}")

          rule ->
            updated = Map.merge(rule, build_rule(params))
            new_rules = List.replace_at(group.rules, pos, updated)
            new_group = %{group | rules: new_rules}
            new_groups = Map.put(fw.groups, group_name, new_group)
            State.update_firewall(:cluster, %{groups: new_groups})
            json_resp(conn, 200, nil)
        end
    end
  end

  def delete_security_group_rule(conn) do
    group_name = conn.path_params["group"]
    pos = parse_pos(conn.path_params["pos"])
    fw = State.get_firewall(:cluster)

    case Map.get(fw.groups, group_name) do
      nil ->
        json_error(conn, 404, "no such security group '#{group_name}'")

      group ->
        if pos < length(group.rules) do
          new_rules = List.delete_at(group.rules, pos)
          new_group = %{group | rules: new_rules}
          new_groups = Map.put(fw.groups, group_name, new_group)
          State.update_firewall(:cluster, %{groups: new_groups})
          json_resp(conn, 200, nil)
        else
          json_error(conn, 400, "no rule at position #{pos}")
        end
    end
  end

  # ────────────────────────────────────────────────
  # Cluster Firewall — static endpoints
  # ────────────────────────────────────────────────

  def get_cluster_firewall_refs(conn), do: do_get_refs(conn)
  def get_cluster_firewall_macros(conn), do: do_get_macros(conn)
  def get_cluster_firewall_log(conn), do: do_get_log(conn)

  # ────────────────────────────────────────────────
  # Node Firewall — public API (thin wrappers)
  # ────────────────────────────────────────────────

  def get_node_firewall_index(conn), do: do_get_firewall_index(conn)
  def get_node_firewall_log(conn), do: do_get_log(conn)

  def get_node_firewall_options(conn) do
    do_get_options(conn, {:node, conn.path_params["node"]})
  end

  def update_node_firewall_options(conn) do
    do_update_options(conn, {:node, conn.path_params["node"]})
  end

  def list_node_firewall_rules(conn) do
    do_list_rules(conn, {:node, conn.path_params["node"]})
  end

  def create_node_firewall_rule(conn) do
    do_create_rule(conn, {:node, conn.path_params["node"]})
  end

  def get_node_firewall_rule(conn) do
    do_get_rule(conn, {:node, conn.path_params["node"]})
  end

  def update_node_firewall_rule(conn) do
    do_update_rule(conn, {:node, conn.path_params["node"]})
  end

  def delete_node_firewall_rule(conn) do
    do_delete_rule(conn, {:node, conn.path_params["node"]})
  end

  # ────────────────────────────────────────────────
  # VM Firewall — public API (thin wrappers)
  # ────────────────────────────────────────────────

  def get_vm_firewall_index(conn), do: do_get_firewall_index(conn)
  def get_vm_firewall_options(conn), do: do_get_options(conn, vm_scope(conn))
  def update_vm_firewall_options(conn), do: do_update_options(conn, vm_scope(conn))
  def list_vm_firewall_rules(conn), do: do_list_rules(conn, vm_scope(conn))
  def create_vm_firewall_rule(conn), do: do_create_rule(conn, vm_scope(conn))
  def get_vm_firewall_rule(conn), do: do_get_rule(conn, vm_scope(conn))
  def update_vm_firewall_rule(conn), do: do_update_rule(conn, vm_scope(conn))
  def delete_vm_firewall_rule(conn), do: do_delete_rule(conn, vm_scope(conn))
  def list_vm_firewall_aliases(conn), do: do_list_aliases(conn, vm_scope(conn))
  def create_vm_firewall_alias(conn), do: do_create_alias(conn, vm_scope(conn))
  def get_vm_firewall_alias(conn), do: do_get_alias(conn, vm_scope(conn))
  def update_vm_firewall_alias(conn), do: do_update_alias(conn, vm_scope(conn))
  def delete_vm_firewall_alias(conn), do: do_delete_alias(conn, vm_scope(conn))
  def list_vm_firewall_ipsets(conn), do: do_list_ipsets(conn, vm_scope(conn))
  def create_vm_firewall_ipset(conn), do: do_create_ipset(conn, vm_scope(conn))
  def get_vm_firewall_ipset(conn), do: do_get_ipset(conn, vm_scope(conn))
  def delete_vm_firewall_ipset(conn), do: do_delete_ipset(conn, vm_scope(conn))
  def add_vm_firewall_ipset_entry(conn), do: do_add_ipset_entry(conn, vm_scope(conn))
  def get_vm_firewall_ipset_entry(conn), do: do_get_ipset_entry(conn, vm_scope(conn))
  def update_vm_firewall_ipset_entry(conn), do: do_update_ipset_entry(conn, vm_scope(conn))
  def delete_vm_firewall_ipset_entry(conn), do: do_delete_ipset_entry(conn, vm_scope(conn))
  def get_vm_firewall_refs(conn), do: do_get_refs(conn)
  def get_vm_firewall_log(conn), do: do_get_log(conn)

  # ────────────────────────────────────────────────
  # Container Firewall — public API (thin wrappers)
  # ────────────────────────────────────────────────

  def get_ct_firewall_index(conn), do: do_get_firewall_index(conn)
  def get_ct_firewall_options(conn), do: do_get_options(conn, ct_scope(conn))
  def update_ct_firewall_options(conn), do: do_update_options(conn, ct_scope(conn))
  def list_ct_firewall_rules(conn), do: do_list_rules(conn, ct_scope(conn))
  def create_ct_firewall_rule(conn), do: do_create_rule(conn, ct_scope(conn))
  def get_ct_firewall_rule(conn), do: do_get_rule(conn, ct_scope(conn))
  def update_ct_firewall_rule(conn), do: do_update_rule(conn, ct_scope(conn))
  def delete_ct_firewall_rule(conn), do: do_delete_rule(conn, ct_scope(conn))
  def list_ct_firewall_aliases(conn), do: do_list_aliases(conn, ct_scope(conn))
  def create_ct_firewall_alias(conn), do: do_create_alias(conn, ct_scope(conn))
  def get_ct_firewall_alias(conn), do: do_get_alias(conn, ct_scope(conn))
  def update_ct_firewall_alias(conn), do: do_update_alias(conn, ct_scope(conn))
  def delete_ct_firewall_alias(conn), do: do_delete_alias(conn, ct_scope(conn))
  def list_ct_firewall_ipsets(conn), do: do_list_ipsets(conn, ct_scope(conn))
  def create_ct_firewall_ipset(conn), do: do_create_ipset(conn, ct_scope(conn))
  def get_ct_firewall_ipset(conn), do: do_get_ipset(conn, ct_scope(conn))
  def delete_ct_firewall_ipset(conn), do: do_delete_ipset(conn, ct_scope(conn))
  def add_ct_firewall_ipset_entry(conn), do: do_add_ipset_entry(conn, ct_scope(conn))
  def get_ct_firewall_ipset_entry(conn), do: do_get_ipset_entry(conn, ct_scope(conn))
  def update_ct_firewall_ipset_entry(conn), do: do_update_ipset_entry(conn, ct_scope(conn))
  def delete_ct_firewall_ipset_entry(conn), do: do_delete_ipset_entry(conn, ct_scope(conn))
  def get_ct_firewall_refs(conn), do: do_get_refs(conn)
  def get_ct_firewall_log(conn), do: do_get_log(conn)

  # ────────────────────────────────────────────────
  # Shared internals — Options
  # ────────────────────────────────────────────────

  defp do_get_options(conn, scope) do
    fw = State.get_firewall(scope)
    json_resp(conn, 200, fw.options)
  end

  defp do_update_options(conn, scope) do
    params = conn.body_params |> atomize_keys()
    fw = State.get_firewall(scope)
    new_options = Map.merge(fw.options, params)
    State.update_firewall(scope, %{options: new_options})
    json_resp(conn, 200, nil)
  end

  # ────────────────────────────────────────────────
  # Shared internals — Rules
  # ────────────────────────────────────────────────

  defp do_list_rules(conn, scope) do
    fw = State.get_firewall(scope)
    json_resp(conn, 200, rules_with_pos(fw.rules))
  end

  defp do_create_rule(conn, scope) do
    params = conn.body_params
    rule = build_rule(params)
    fw = State.get_firewall(scope)
    new_rules = fw.rules ++ [rule]
    State.update_firewall(scope, %{rules: new_rules})
    json_resp(conn, 200, nil)
  end

  defp do_get_rule(conn, scope) do
    pos = parse_pos(conn.path_params["pos"])
    fw = State.get_firewall(scope)

    case Enum.at(fw.rules, pos) do
      nil -> json_error(conn, 400, "no rule at position #{pos}")
      rule -> json_resp(conn, 200, Map.put(rule, :pos, pos))
    end
  end

  defp do_update_rule(conn, scope) do
    pos = parse_pos(conn.path_params["pos"])
    params = conn.body_params
    fw = State.get_firewall(scope)

    case Enum.at(fw.rules, pos) do
      nil ->
        json_error(conn, 400, "no rule at position #{pos}")

      rule ->
        updated = Map.merge(rule, build_rule(params))
        new_rules = List.replace_at(fw.rules, pos, updated)
        State.update_firewall(scope, %{rules: new_rules})
        json_resp(conn, 200, nil)
    end
  end

  defp do_delete_rule(conn, scope) do
    pos = parse_pos(conn.path_params["pos"])
    fw = State.get_firewall(scope)

    if pos < length(fw.rules) do
      new_rules = List.delete_at(fw.rules, pos)
      State.update_firewall(scope, %{rules: new_rules})
      json_resp(conn, 200, nil)
    else
      json_error(conn, 400, "no rule at position #{pos}")
    end
  end

  # ────────────────────────────────────────────────
  # Shared internals — Aliases
  # ────────────────────────────────────────────────

  defp do_list_aliases(conn, scope) do
    fw = State.get_firewall(scope)

    aliases =
      Enum.map(fw.aliases, fn {name, alias_entry} ->
        Map.merge(alias_entry, %{name: name})
      end)

    json_resp(conn, 200, aliases)
  end

  defp do_create_alias(conn, scope) do
    params = conn.body_params
    name = Map.get(params, "name")

    if name do
      fw = State.get_firewall(scope)

      if Map.has_key?(fw.aliases, name) do
        json_error(conn, 400, "alias '#{name}' already exists")
      else
        alias_entry = %{
          cidr: Map.get(params, "cidr", ""),
          comment: Map.get(params, "comment", "")
        }

        new_aliases = Map.put(fw.aliases, name, alias_entry)
        State.update_firewall(scope, %{aliases: new_aliases})
        json_resp(conn, 200, nil)
      end
    else
      json_error(conn, 400, "property 'name' is missing and it is not optional")
    end
  end

  defp do_get_alias(conn, scope) do
    name = conn.path_params["name"]
    fw = State.get_firewall(scope)

    case Map.get(fw.aliases, name) do
      nil -> json_error(conn, 404, "no such alias '#{name}'")
      alias_entry -> json_resp(conn, 200, Map.put(alias_entry, :name, name))
    end
  end

  defp do_update_alias(conn, scope) do
    name = conn.path_params["name"]
    params = conn.body_params
    fw = State.get_firewall(scope)

    case Map.get(fw.aliases, name) do
      nil ->
        json_error(conn, 404, "no such alias '#{name}'")

      alias_entry ->
        updated =
          alias_entry
          |> maybe_put(:cidr, Map.get(params, "cidr"))
          |> maybe_put(:comment, Map.get(params, "comment"))

        new_aliases = Map.put(fw.aliases, name, updated)
        State.update_firewall(scope, %{aliases: new_aliases})
        json_resp(conn, 200, nil)
    end
  end

  defp do_delete_alias(conn, scope) do
    name = conn.path_params["name"]
    fw = State.get_firewall(scope)

    if Map.has_key?(fw.aliases, name) do
      new_aliases = Map.delete(fw.aliases, name)
      State.update_firewall(scope, %{aliases: new_aliases})
      json_resp(conn, 200, nil)
    else
      json_error(conn, 404, "no such alias '#{name}'")
    end
  end

  # ────────────────────────────────────────────────
  # Shared internals — IP Sets
  # ────────────────────────────────────────────────

  defp do_list_ipsets(conn, scope) do
    fw = State.get_firewall(scope)

    ipsets =
      Enum.map(fw.ipsets, fn {name, ipset} ->
        %{name: name, comment: Map.get(ipset, :comment, ""), count: length(ipset.entries)}
      end)

    json_resp(conn, 200, ipsets)
  end

  defp do_create_ipset(conn, scope) do
    params = conn.body_params
    name = Map.get(params, "name")

    if name do
      fw = State.get_firewall(scope)

      if Map.has_key?(fw.ipsets, name) do
        json_error(conn, 400, "IP set '#{name}' already exists")
      else
        ipset = %{comment: Map.get(params, "comment", ""), entries: []}
        new_ipsets = Map.put(fw.ipsets, name, ipset)
        State.update_firewall(scope, %{ipsets: new_ipsets})
        json_resp(conn, 200, nil)
      end
    else
      json_error(conn, 400, "property 'name' is missing and it is not optional")
    end
  end

  defp do_get_ipset(conn, scope) do
    name = conn.path_params["name"]
    fw = State.get_firewall(scope)

    case Map.get(fw.ipsets, name) do
      nil -> json_error(conn, 404, "no such IP set '#{name}'")
      ipset -> json_resp(conn, 200, ipset.entries)
    end
  end

  defp do_delete_ipset(conn, scope) do
    name = conn.path_params["name"]
    fw = State.get_firewall(scope)

    if Map.has_key?(fw.ipsets, name) do
      new_ipsets = Map.delete(fw.ipsets, name)
      State.update_firewall(scope, %{ipsets: new_ipsets})
      json_resp(conn, 200, nil)
    else
      json_error(conn, 404, "no such IP set '#{name}'")
    end
  end

  defp do_get_ipset_entry(conn, scope) do
    name = conn.path_params["name"]
    cidr = cidr_from_path(conn.path_params["cidr"])
    fw = State.get_firewall(scope)

    case Map.get(fw.ipsets, name) do
      nil ->
        json_error(conn, 404, "no such IP set '#{name}'")

      ipset ->
        case Enum.find(ipset.entries, &(&1.cidr == cidr)) do
          nil -> json_error(conn, 404, "no such entry '#{cidr}' in IP set '#{name}'")
          entry -> json_resp(conn, 200, entry)
        end
    end
  end

  defp do_update_ipset_entry(conn, scope) do
    name = conn.path_params["name"]
    cidr = cidr_from_path(conn.path_params["cidr"])
    params = conn.body_params
    fw = State.get_firewall(scope)

    case Map.get(fw.ipsets, name) do
      nil ->
        json_error(conn, 404, "no such IP set '#{name}'")

      ipset ->
        case Enum.find_index(ipset.entries, &(&1.cidr == cidr)) do
          nil ->
            json_error(conn, 404, "no such entry '#{cidr}' in IP set '#{name}'")

          idx ->
            entry = Enum.at(ipset.entries, idx)

            updated =
              entry
              |> maybe_put(:comment, Map.get(params, "comment"))
              |> maybe_put(:nomatch, Map.get(params, "nomatch"))

            new_entries = List.replace_at(ipset.entries, idx, updated)
            new_ipset = %{ipset | entries: new_entries}
            new_ipsets = Map.put(fw.ipsets, name, new_ipset)
            State.update_firewall(scope, %{ipsets: new_ipsets})
            json_resp(conn, 200, nil)
        end
    end
  end

  defp do_delete_ipset_entry(conn, scope) do
    name = conn.path_params["name"]
    cidr = cidr_from_path(conn.path_params["cidr"])
    fw = State.get_firewall(scope)

    case Map.get(fw.ipsets, name) do
      nil ->
        json_error(conn, 404, "no such IP set '#{name}'")

      ipset ->
        new_entries = Enum.reject(ipset.entries, &(&1.cidr == cidr))

        if length(new_entries) == length(ipset.entries) do
          json_error(conn, 404, "no such entry '#{cidr}' in IP set '#{name}'")
        else
          new_ipset = %{ipset | entries: new_entries}
          new_ipsets = Map.put(fw.ipsets, name, new_ipset)
          State.update_firewall(scope, %{ipsets: new_ipsets})
          json_resp(conn, 200, nil)
        end
    end
  end

  defp do_add_ipset_entry(conn, scope) do
    name = conn.path_params["name"]
    params = conn.body_params
    cidr = Map.get(params, "cidr")

    if cidr do
      fw = State.get_firewall(scope)

      case Map.get(fw.ipsets, name) do
        nil ->
          json_error(conn, 404, "no such IP set '#{name}'")

        ipset ->
          if Enum.any?(ipset.entries, &(&1.cidr == cidr)) do
            json_error(conn, 400, "entry '#{cidr}' already exists in IP set '#{name}'")
          else
            entry = %{
              cidr: cidr,
              comment: Map.get(params, "comment", ""),
              nomatch: Map.get(params, "nomatch", false)
            }

            new_ipset = %{ipset | entries: ipset.entries ++ [entry]}
            new_ipsets = Map.put(fw.ipsets, name, new_ipset)
            State.update_firewall(scope, %{ipsets: new_ipsets})
            json_resp(conn, 200, nil)
          end
      end
    else
      json_error(conn, 400, "property 'cidr' is missing and it is not optional")
    end
  end

  # ────────────────────────────────────────────────
  # Static endpoints — index, refs, log
  # ────────────────────────────────────────────────

  defp do_get_firewall_index(conn) do
    data = [
      %{name: "aliases"},
      %{name: "ipset"},
      %{name: "options"},
      %{name: "rules"},
      %{name: "refs"},
      %{name: "log"}
    ]

    json_resp(conn, 200, data)
  end

  defp do_get_refs(conn) do
    data = [
      %{type: "alias", comment: "IP alias"},
      %{type: "ipset", comment: "IP set"},
      %{type: "+ipset", comment: "IP set (nomatch)"}
    ]

    json_resp(conn, 200, data)
  end

  defp do_get_macros(conn) do
    data = [
      %{macro: "Apache", descr: "Web server (HTTP/HTTPS)"},
      %{macro: "DNS", descr: "Domain Name System traffic"},
      %{macro: "FTP", descr: "File Transfer Protocol"},
      %{macro: "HTTP", descr: "Hypertext Transfer Protocol (WWW)"},
      %{macro: "HTTPS", descr: "Hypertext Transfer Protocol (WWW) over SSL"},
      %{macro: "IMAP", descr: "Internet Message Access Protocol"},
      %{macro: "NTP", descr: "Network Time Protocol"},
      %{macro: "Ping", descr: "ICMP echo request"},
      %{macro: "SSH", descr: "Secure Shell"},
      %{macro: "SMB", descr: "Samba (Windows file/printer sharing)"},
      %{macro: "SMTP", descr: "Simple Mail Transfer Protocol"},
      %{macro: "SNMP", descr: "Simple Network Management Protocol"},
      %{macro: "Syslog", descr: "Syslog protocol"},
      %{macro: "Telnet", descr: "Telnet protocol"}
    ]

    json_resp(conn, 200, data)
  end

  defp do_get_log(conn) do
    json_resp(conn, 200, [])
  end

  # ────────────────────────────────────────────────
  # Private Helpers
  # ────────────────────────────────────────────────

  defp json_resp(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(%{data: data}))
  end

  defp json_error(conn, status, message) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(%{errors: %{message: message}}))
  end

  defp build_rule(params) do
    %{
      type: Map.get(params, "type", "in"),
      action: Map.get(params, "action", "ACCEPT"),
      enable: Map.get(params, "enable", 1),
      comment: Map.get(params, "comment", ""),
      source: Map.get(params, "source"),
      dest: Map.get(params, "dest"),
      proto: Map.get(params, "proto"),
      dport: Map.get(params, "dport"),
      sport: Map.get(params, "sport"),
      macro: Map.get(params, "macro"),
      iface: Map.get(params, "iface"),
      log: Map.get(params, "log")
    }
  end

  defp rules_with_pos(rules) do
    rules
    |> Enum.with_index()
    |> Enum.map(fn {rule, idx} -> Map.put(rule, :pos, idx) end)
  end

  defp parse_pos(pos_str) do
    case Integer.parse(pos_str) do
      {pos, _} -> pos
      :error -> 0
    end
  end

  defp cidr_from_path(cidr_param) do
    # URL paths use dash notation (10.0.0.0-24) to avoid path separator conflicts
    String.replace(cidr_param, "-", "/")
  end

  defp atomize_keys(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
